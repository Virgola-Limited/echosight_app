class BugReportsController < AuthenticatedController
  def index
    @bug_reports = BugReport.left_joins(:votes)
                            .group(:id)
                            .order('COUNT(votes.id) DESC')
    @new_bug_report = BugReport.new
  end

  def create
    @bug_report = BugReport.new(bug_report_params)
    if @bug_report.save
      redirect_to bug_reports_path, notice: 'Bug report added successfully.'
    else
      render :index
    end
  end

  private

  def bug_report_params
    params.require(:bug_report).permit(:description)
  end
end
