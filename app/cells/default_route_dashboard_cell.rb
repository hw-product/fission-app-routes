class DefaultRouteDashboardCell < DashboardCell

  def show(args)
    super
    dataset = Job.dataset_with(
      :scalars => {
        :status => ['status'],
        :route_name => ['data', 'router', 'action']
      }
    ).where(
      :id => Job.current_dataset_ids,
      :account_id => current_user.run_state.current_account.id,
      :route_name => args[:route].name
    )
    #   .where{
    #   created_at >= 7.days.ago
    # }
    # @jobs_summary = {
    #   :in_progress => dataset.where(:status => 'active').count,
    #   :error => dataset.where(:status => 'error').count,
    #   :complete => dataset.where(:status => 'complete').count
    # }
    @recent = dataset.order(:id.desc).limit(5).all
    render
  end

end
