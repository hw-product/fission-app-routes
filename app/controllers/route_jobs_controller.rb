class RouteJobsController < JobsController

  before_action do
    if(params[:pipeline_name])
      pipeline = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      if(pipeline && session[:route_id] != pipeline.id)
        session[:route_id] = pipeline.id
        redirect_to url_for(params)
      end
    end
    @namespace = params[:namespace] = 'pipeline'
  end

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
    @namespace = params[:namespace] = 'pipeline'
  end

end
