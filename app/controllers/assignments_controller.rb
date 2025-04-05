class AssignmentsController < ApplicationController
  include BubbleScoped, BucketScoped

  def new
    render partial: "bubbles/assignment", locals: { bubble: @bubble }
  end

  def create
    new_assignee_ids = Array(params[:assignee_id])
    current_assignees = @bubble.assignees

    current_assignees.each do |assignee|
      @bubble.toggle_assignment(assignee) unless new_assignee_ids.include?(assignee.id.to_s)
    end

    new_assignee_ids.each do |id|
      assignee = @bucket.users.active.find(id)
      @bubble.toggle_assignment(assignee) unless current_assignees.include?(assignee)
    end

    @bubble.assignees.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace([ @bubble, :assignees ], partial: "bubbles/cards/perma/assignees", locals: { bubble: @bubble })
      end
    end
  end

  private
    def assignee
      @bucket.users.active.find params[:assignee_id]
    end
end
