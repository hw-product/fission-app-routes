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
      end
    end
  end

  def create
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
        end
      end
    end
  end

  def update
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

end
