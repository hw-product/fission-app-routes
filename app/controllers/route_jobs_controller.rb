class RouteJobsController < JobsController

  protected

  def set_valid_jobs
    @product = Product.find_by_internal_name('routes')
    if(session[:route_id])
      @route = @account.routes_dataset.where(:id => session[:route_id]).first
    end
    unless(@route)
      raise 'No pipeline currently selected!'
    end
    params[:namespace] = @route.name
    super
    params[:namespace] = 'pipeline'
  end

end
