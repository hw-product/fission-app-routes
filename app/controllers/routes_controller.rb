class RoutesController < ApplicationController

  before_action do
    if(params[:pipeline_name])
      pipeline = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      if(pipeline && session[:route_id] != pipeline.id)
        session[:route_id] = pipeline.id
        redirect_to url_for(params)
      end
    end
  end

  def dashboard
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to pipeline_dashboard_path
      end
      format.html do
        @route = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      end
    end
  end

  def prebuilt
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to pipeline_dashboard_path
      end
      format.html do
        @groups = ServiceGroup.all.find_all do |sg|
          sg.services.all? do |srv|
            @account.services.include?(srv)
          end
        end.sort_by(&:generated_cost).push(nil)
      end
    end
  end

  def apply_prebuilt
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to pipeline_dashboard_path
      end
      format.html do
        group = ServiceGroup.all.find_all do |sg|
          sg.services.all? do |srv|
            @account.services.include?(srv)
          end
        end.detect do |sg|
          sg.id == params[:service_group_id].to_i
        end
        if(group)
          route = Route.create(
            :name => group.name,
            :account_id => @account.id,
            :description => group.description
          )
          group.services.each_with_index do |srv, idx|
            route.add_service(
              :service => srv,
              :position => idx
            )
          end
          group.service_group_payload_filters.each do |filter|
            r_filter = Fission::Data::Models::RoutePayloadFilter.find_or_create(
              :name => filter.name,
              :description => filter.description,
              :route_id => route.id
            )
            filter.payload_matchers.each do |matcher|
              new_matcher = Fission::Data::Models::PayloadMatcher.find_or_create(
                :value => matcher.value,
                :payload_match_rule_id => matcher.payload_match_rule_id,
                :account_id => @account.id
              )
              r_filter.add_payload_matcher(new_matcher)
            end
          end
          flash[:success] = 'New pipeline successfully created!'
          redirect_to pipeline_dashboard_path(:pipeline_name => route.name)
        else
          flash[:error] = 'Failed to locate requested pipeline for setup!'
          redirect_to prebuilt_routes_path
        end
      end
    end
  end

  def index
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @routes = @account.routes
      end
    end
  end

  def show
    route = @account.routes_dataset.where(:id => params[:id]).first
    if(route)
      session[:route_id] = route.id
      flash[:success] = "Pipeline loaded: #{route.name}"
    else
      session.delete(:route_id)
      if(params[:id].to_i == 0)
        flash[:success] = 'Pipeline has been unset!'
      else
        flash[:error] = 'Failed to locate requested pipeline'
      end
    end
    respond_to do |format|
      format.js do
        javascript_redirect_to pipeline_jobs_path(:pipeline_name => route.name)
      end
      format.html do
        redirect_to pipeline_dashboard_path(:pipeline_name => route.name)
      end
    end
  end

  def new
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name)
        @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name)
        @custom_services = @account.custom_services_dataset.order(:name).all
      end
    end
  end

  def create
    save_route!
    flash[:success] = 'Created new pipeline!'
    respond_to do |format|
      format.js do
        javascript_redirect_to routes_path
      end
      format.html do
        redirect_to routes_path
      end
    end
  end

  def edit
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @route = @account.routes_dataset.where(:id => params[:id]).first
        unless(@route)
          flash[:error] = 'Failed to locate requested pipeline'
          redirect_to routes_path
        else
          @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name) - (@route.services || [])
          @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name) - (@route.service_groups || [])
          @custom_services = @account.custom_services_dataset.order(:name).all - (@route.custom_services || [])
          @configs = @account.account_configs_dataset.order(:name).all
          @match_rules = PayloadMatchRule.order(:name).all
        end
      end
    end
  end

  def update
    route = @account.routes_dataset.where(:id => params[:id]).first
    if(route)
      if(route.description != params[:description])
        route.description = params[:description]
        route.save
      end
      save_route!(route)
      flash[:success] = 'Updated pipeline!'
    else
      flash[:error] = 'Failed to locate requested pipeline!'
    end
    respond_to do |format|
      format.js do
        javascript_redirect_to routes_path
      end
      format.html do
        redirect_to routes_path
      end
    end
  end

  def destroy
    respond_to do |format|
      format.js do
        route = @account.routes_dataset.where(:id => params[:id]).first
        if(route)
          name = route.name
          route.destroy
          flash[:success] = "Pipeline has been destroyed! (#{name})"
        else
          flash[:error] = 'Failed to located requested pipeline'
        end
        javascript_redirect_to routes_path
      end
      format.html do
        @route = @account.routes_dataset.where(:id => params[:id]).first
        unless(@route)
          flash[:error] = 'Failed to locate requested pipeline'
          redirect_to routes_path
        end
        name = @route.name
        @route.destroy
        flash[:success] = "Pipeline has been destroyed! (#{name})"
        redirect_to routes_path
      end
    end
  end

  # route config packs

  def add_config_rule
    respond_to do |format|
      format.js do
        @rule = PayloadMatchRule.find_by_id(params[:rule])
        @identifier = params[:identifier]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def apply_config_rule
    respond_to do |format|
      format.js do
        @rule = PayloadMatchRule.find_by_id(params[:rule_id])
        @identifier = params[:identifier]
        @value = params[:value]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def remove_config_rule
    respond_to do |format|
      format.js do
        @rule_ident = params[:rule_ident]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def add_config
    respond_to do |format|
      format.js do
        @configs = @account.account_configs_dataset.order(:name).all
        @match_rules = PayloadMatchRule.order(:name).all
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def remove_config
    respond_to do |format|
      format.js do
        @ident = params[:ident]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  # route filters

  def add_filter_rule
    respond_to do |format|
      format.js do
        @rule = PayloadMatchRule.find_by_id(params[:rule])
        @identifier = params[:identifier]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def apply_filter_rule
    respond_to do |format|
      format.js do
        @rule = PayloadMatchRule.find_by_id(params[:rule_id])
        @identifier = params[:identifier]
        @value = params[:value]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def remove_filter_rule
    respond_to do |format|
      format.js do
        @rule_ident = params[:rule_ident]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def add_filter
    respond_to do |format|
      format.js do
        @match_rules = PayloadMatchRule.order(:name).all
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def remove_filter
    respond_to do |format|
      format.js do
        @ident = params[:ident]
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def add_service
    respond_to do |format|
      format.js do
        params[:data] = params[:data].values.flatten.compact
        @items = Smash.new
        @items['Service'] = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name).find_all do |item|
          params[:data].any? do |x|
            x['type'] == item.class.to_s.split('::').last && x['id'] == item.id.to_s
          end
        end
        @items['ServiceGroup'] = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name).find_all do |item|
          params[:data].any? do |x|
            x['type'] == item.class.to_s.split('::').last && x['id'] == item.id.to_s
          end
        end
        @items['CustomService'] = @account.custom_services_dataset.order(:name).all.find_all do |item|
          params[:data].any? do |x|
            x['type'] == item.class.to_s.split('::').last && x['id'] == item.id.to_s
          end
        end
        @route_items = params[:data].map do |item|
          @items[item['type']].detect{|x| x.id.to_s == item['id']}
        end
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def add_service_list
    respond_to do |format|
      format.js do
        params[:data] ||= {}
        @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name).find_all do |item|
          !params[:data].fetch('Service', []).include?(item.id.to_s)
        end
        @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name).find_all do |item|
          !params[:data].fetch('ServiceGroup', []).include?(item.id.to_s)
        end
        @custom_services = @account.custom_services_dataset.order(:name).all.find_all do |item|
          !params[:data].fetch('CustomService', []).include?(item.id.to_s)
        end
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def add_configurator
    respond_to do |format|
      format.js do

      end
      format.html do
        flash[:error] = 'Unsupported request'
        redirect_to routes_path
      end
    end
  end

  def edit_configurator
    respond_to do |format|
      format.js do
        @name = params[:configurator]
        @description = params[:data][@name][:description]
        @configs = @account.account_configs_dataset.order(:name).all
        @set_rules = params[:data][@name].fetch('matchers', {})
        @rules = Hash[
          PayloadMatchRule.order(:name).all.map do |rule|
            [rule, @set_rules[rule.id.to_s]]
          end
        ]
        @set_configs = params[:data][@name].fetch(:configs, []).map do |c_id|
          @configs.detect{|config| config.id.to_s == c_id}
        end
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to dashboard_path
      end
    end
  end

  def preview_configurator
    respond_to do |format|
      format.js do
        unless(params.fetch(:pack_ids, []).empty?)
          configs = @account.account_configs_dataset.where(:id => params[:pack_ids]).all
          configs = params[:pack_ids].map do |c_id|
            configs.detect{|c| c.id.to_s == c_id}
          end
          @configuration = Smash.new
          configs.reverse.map do |item|
            @configuration.deep_merge!(item.data)
          end
        else
          @configuration = {}
        end
        @configuration = JSON.pretty_generate(@configuration.to_hash)
      end
      format.html do
        flash[:error] = 'Unsupported request!'
        redirect_to routes_path
      end
    end
  end

  protected

  def save_reformat!
    if(params[:route_items])
      params[:service] = params[:route_items].map do |pos, data|
        [pos, data['id']] if data['type'] == 'Service'
      end.compact
      params['service-group'] = params[:route_items].map do |pos, data|
        [pos, data['id']] if data['type'] == 'ServiceGroup'
      end.compact
      params['custom-service'] = params[:route_items].map do |pos, data|
        [pos, data['id']] if data['type'] == 'CustomService'
      end.compact
    end
    if(params[:configurators])
      params[:configs] = Smash[
        params[:configurators].map do |c_name, c_info|
          [c_name, Smash.new(
              :name => c_name,
              :description => c_info[:description],
              :config_id => c_info[:configs],
              :rule_id => Smash[c_info[:matchers].map{|k,v| [k, {k => v}]}]
          )]
        end
      ]
      params[:filters] = Smash[
        params[:configurators].map do |c_name, c_info|
          unless(c_info[:matchers].empty?)
            [c_name, Smash.new(
                :name => c_name,
                :description => c_info[:description],
                :rule_id => Smash[
                  c_info[:matchers].map do |k,v|
                    [k, {k => v}]
                  end
                ]
            )]
          end
        end.compact
      ]
    end
  end

  def save_route!(route=nil)
    save_reformat!
    unless(route)
      route = Route.find_or_create(
        :name => Bogo::Utility.snake(params[:name]).tr(' ', '_'),
        :description => params[:description],
        :account_id => @account.id
      )
    end
    services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name)
    service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name)
    custom_services = @account.custom_services
    route.remove_all_services
    route.remove_all_service_groups
    route.remove_all_custom_services
    params.fetch(:service, []).each do |position, srv_id|
      srv = services.detect{|s| s.id == srv_id.to_i}
      route.add_service(
        :position => position,
        :service => srv
      )
    end
    params.fetch('service-group', []).each do |position, grp_id|
      grp = service_groups.detect{|s| s.id == grp_id.to_i}
      route.add_service_group(
        :position => position,
        :service_group => grp
      )
    end
    params.fetch('custom-service', []).each do |position, grp_id|
      srv = custom_services.detect{|s| s.id == grp_id.to_i}
      route.add_custom_service(
        :position => position,
        :custom_service => srv
      )
    end
    t_idx = 0
    r_config_ids = params.fetch('configs', {}).map do |ident, config|
      t_idx = t_idx.next
      r_config = RouteConfig.find_or_create(
        :name => config[:name],
        :description => config[:description],
        :position => t_idx,
        :route_id => route.id
      )
      r_config.remove_all_account_configs
      if(config)
        config.fetch(:config_id, []).each_with_index do |c_id, c_idx|
          account_config = @account.account_configs_dataset.where(:id => c_id).first
          r_config.add_account_config(
            :account_config => account_config,
            :position => c_idx
          )
        end
      end
      r_config.remove_all_payload_matchers
      if(config)
        config.fetch(:rule_id, {}).each do |r_idx, r_pair|
          matcher = PayloadMatcher.find_or_create(
            :payload_match_rule_id => r_pair.keys.first,
            :account_id => @account.id,
            :value => r_pair.values.first
          )
          r_config.add_payload_matcher(matcher)
        end
      end
      r_config.id
    end
    deleted_configs = route.route_configs.map(&:id) - r_config_ids
    unless(deleted_configs.empty?)
      RouteConfig.where(:id => deleted_configs).destroy
    end
    t_idx = 0
    r_filter_ids = params.fetch('filters', {}).map do |ident, filter|
      t_idx = t_idx.next
      r_filter = RoutePayloadFilter.find_or_create(
        :name => filter[:name],
        :description => filter[:description],
        :route_id => route.id
      )
      if(filter)
        current_matchers = r_filter.payload_matchers.dup
        filter.fetch(:rule_id, {}).each do |r_idx, r_pair|
          matcher = PayloadMatcher.find_or_create(
            :payload_match_rule_id => r_pair.keys.first,
            :account_id => @account.id,
            :value => r_pair.values.first
          )
          if(current_matchers.include?(matcher))
            current_matchers.delete(matcher)
          else
            r_filter.add_payload_matcher(matcher)
          end
        end
        current_matchers.each do |stale_matcher|
          r_filter.remove_payload_matcher(stale_matcher)
        end
      end
    end
  end

end
