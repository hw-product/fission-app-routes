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
        @configs = @account.account_configs_dataset.order(:name).all
        @match_rules = PayloadMatchRule.order(:name).all
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
        route = Route.create(
          :name => Bogo::Utility.snake(params[:name]).tr(' ', '_'),
          :description => params[:description],
          :account_id => @account.id
        )
        @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name)
        @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name)
        @custom_services = @account.custom_services
        params.fetch(:service, []).each do |position, srv_id|
          route.add_service(
            :position => position,
            :service => @services.detect{|s| s.id == srv_id.to_i}
          )
        end
        params.fetch('service-group', []).each do |position, grp_id|
          route.add_service_group(
            :position => position,
            :service_group => @service_groups.detect{|s| s.id == grp_id.to_i}
          )
        end
        params.fetch('custom-service', []).each do |position, grp_id|
          route.add_custom_service(
            :position => position,
            :custom_service => @custom_services.detect{|s| s.id == grp_id.to_i}
          )
        end
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
        @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name) - (@route.services || [])
        @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name) - (@route.service_groups || [])
        @custom_services = @account.custom_services_dataset.order(:name).all - (@route.custom_services || [])
        unless(@route)
          flash[:error] = 'Failed to locate requested route'
          redirect_to routes_path
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
        route = Route.find_by_id(params[:id])
        if(route)
          route.remove_all_services
          route.remove_all_custom_services
          route.remove_all_service_groups
          unless(route.description == params[:description])
            route.description = params[:description]
            route.save
          end
          @services = @account.product_features.map(&:services).flatten.uniq.sort_by(&:name)
          @service_groups = @account.product_features.map(&:service_groups).flatten.uniq.sort_by(&:name)
          @custom_services = @account.custom_services
          params.fetch(:service, []).each do |position, srv_id|
            route.add_service(
              :position => position,
              :service => @services.detect{|s| s.id == srv_id.to_i}
            )
          end
          params.fetch('service-group', []).each do |position, grp_id|
            route.add_service_group(
              :position => position,
              :service_group => @service_groups.detect{|s| s.id == grp_id.to_i}
            )
          end
          params.fetch('custom-service', []).each do |position, grp_id|
            route.add_custom_service(
              :position => position,
              :custom_service => @custom_services.detect{|s| s.id == grp_id.to_i}
            )
          end
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

end
