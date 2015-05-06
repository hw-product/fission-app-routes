class RoutesController < ApplicationController

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
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        save_route!
        flash[:success] = 'Created new route!'
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
          flash[:error] = 'Failed to locate requested route'
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
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        route = @account.routes_dataset.where(:id => params[:id]).first
        if(route)
          if(route.description != params[:description])
            route.description = params[:description]
            route.save
          end
          save_route!(route)
          flash[:success] = 'Updated route!'
          redirect_to routes_path
        else
          flash[:error] = 'Failed to locate requested route!'
          redirect_to routes_path
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @route = @account.routes_dataset.where(:id => params[:id]).first
        unless(@route)
          flash[:error] = 'Failed to locate requested route'
          redirect_to routes_path
        end
        @route.destroy
        flash[:success] = 'Route has been deleted!'
        redirect_to routes_path
      end
    end
  end

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

  private

  def save_route!(route=nil)
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
    r_config_ids = params.fetch('configs', {}).map do |ident, config|
      r_config = RouteConfig.find_or_create(
        :name => config[:name],
        :description => config[:description],
        :route_id => route.id
      )
      r_config.remove_all_account_configs
      config[:config_id].each_with_index do |c_id, c_idx|
        account_config = @account.account_configs_dataset.where(:id => c_id).first
        r_config.add_account_config(
          :account_config => account_config,
          :position => c_idx
        )
      end
      r_config.remove_all_payload_matchers
      config[:rule_id].each do |r_idx, r_pair|
        matcher = PayloadMatcher.find_or_create(
          :payload_match_rule_id => r_pair.keys.first,
          :account_id => @account.id,
          :value => r_pair.values.first
        )
        r_config.add_payload_matcher(matcher)
      end
      r_config.id
    end
    deleted_configs = route.route_configs.map(&:id) - r_config_ids
    unless(deleted_configs.empty?)
      RouteConfig.where(:id => deleted_configs).destroy
    end
  end

end
