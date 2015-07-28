class RouteJobsController < JobsController

  protected

  def set_valid_jobs
    @product = Product.find_by_internal_name('routes')
    if(params[:pipeline_name] && @pipeline.try(:name) != params[:pipeline_name])
      @route = @pipeline = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      if(@route)
        session[:route_id] = @route.id
        flash[:info] = "Loaded pipeline: #{@route.name.humanize}"
      end
    elsif(session[:route_id])
      @route = @account.routes_dataset.where(:id => session[:route_id]).first
    elsif(@preload_job)
      @route = @account.routes_dataset.where(
        :name => @preload_job.payload.get(:data, :router, :action)
      ).first
    end
    unless(@route)
      raise 'No pipeline currently selected!'
    end
    params[:namespace] = @route.name
    super
    @namespace = params[:namespace] = 'pipeline'
  end

  def set_job_account
    if(params[:job_id])
      @preload_job = Job.where(:message_id => params[:job_id]).last
      if(@preload_job && @preload_job.account_id && @preload_job.account_id != @account.id)
        redirect_to pipeline_job_path(
          :job_id => params[:job_id],
          :account_id => @preload_job.account.id,
          :pipeline_name => @preload_job.payload.get(:data, :router, :action)
        )
      end
    end
  end

end
