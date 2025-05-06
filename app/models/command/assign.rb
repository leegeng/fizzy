class Command::Assign < Command
  store_accessor :data, :card_ids, :assignee_ids, :toggled_assignees_by_card

  validates_presence_of :card_ids, :assignee_ids

  def title
    card_description = if cards.one?
      "card '#{cards.first.title}'"
    else
      "#{cards.count} cards"
    end

    assignee_description = assignees.collect(&:first_name).join(", ")

    "Assign #{assignee_description} to #{card_description}"
  end

  def execute
    toggled_assignees_by_card = {}

    transaction do
      cards.each do |card|
        toggled_assignees_by_card[card.id] = []
        assignees.each do |assignee|
          unless card.assigned_to?(assignee)
            toggled_assignees_by_card[card.id] << assignee.id
            card.toggle_assignment(assignee)
          end
        end
      end

      update! toggled_assignees_by_card: toggled_assignees_by_card
    end
  end

  def undo
    toggled_assignees_by_card.each do |card_id, assignee_ids|
      card = user.accessible_cards.find_by_id(card_id)
      assignees = User.where(id: assignee_ids)

      if card && assignees.any?
        assignees.each do |assignee|
          card.toggle_assignment(assignee) if card.assigned_to?(assignee)
        end
      end
    end
  end

  def undoable?
    true
  end

  private
    def assignees
      User.where(id: assignee_ids)
    end

    def cards
      user.accessible_cards.where(id: card_ids)
    end
end
