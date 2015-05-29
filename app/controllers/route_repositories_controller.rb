class RouteRepositoriesController < RepositoriesController

  before_action do
    if(params[:pipeline_name])
      pipeline = @account.routes_dataset.where(:name => params[:pipeline_name]).first
      if(pipeline && session[:route_id] != pipeline.id)
        session[:route_id] = pipeline.id
        redirect_to url_for(params)
      end
    end
  end

  def set_product
    unless(session[:route_id].blank?)
      params[:namespace] = 'routes'
      super
      @namespace = 'pipeline'
      @base = @account.routes_dataset.where(:id => session[:route_id]).first
    end
    unless(@base)
      raise 'No pipeline currently selected!'
    end
  end

  def commit_hook_url
    File.join(
      Rails.application.config.settings.get(:fission, :rest_endpoint_ssl),
      'v1/github', @base.name
    )
  end

  def hook_identifier
    "fission_#{@account.id}_#{@base.name}"
  end

end
