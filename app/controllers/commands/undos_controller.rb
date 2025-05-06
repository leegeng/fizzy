class Commands::UndosController < ApplicationController
  before_action :set_command

  def create
    @command.undo
    @command.destroy
    redirect_back_or_to root_path
  end

  private
    def set_command
      @command = Current.user.commands.find(params[:command_id])
    end
end
