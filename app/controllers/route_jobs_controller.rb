class RouteJobsController < JobsController

  protected

  def set_valid_jobs
    @product = Product.find_by_internal_name('routes')
    if(params[:pipeline_name])
      @route = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      if(@route)
        session[:route_id] = @route.id
        flash[:info] = "Loaded pipeline: #{@pipeline.name.humanize}"
      end
    elsif(session[:route_id])
      @route = @account.routes_dataset.where(:id => session[:route_id]).first
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
      job = Job.where(:message_id => params[:job_id]).first
      if(job.account_id && job.account_id != @account.id)
        redirect_to pipeline_job_path(
          :job_id => params[:job_id],
          :account_id => job.account.id,
          :pipeline_name => job.payload.get(:data, :router, :action)
        )
      end
    end
  end

end
