class Command::Search < Command
  store_accessor :data, :query

  def title
    "Search '#{query}'"
  end

  def execute
    redirect_to cards_path("terms[]": query.presence)
  end
end
