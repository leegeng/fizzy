namespace :import do
  desc "Import cards from JSON files in a folder"
  task :cards, [:folder] => :environment do |t, args|
    folder = args[:folder]
    unless folder.present? && Dir.exist?(folder)
      puts "Usage: rails import:cards[path/to/folder]"
      exit 1
    end

    # 1. Setup Context
    account = Account.first
    unless account
      puts "No account found. Creating a default one..."
      account = Account.create!(name: "Imported Account")
    end

    # The first user is System
    default_creator = User.last
    unless default_creator
      puts "No user found. Please seed the database first."
      exit 1
    end

    puts "Using Account: #{account.name}"
    puts "Using Creator: #{default_creator.name}"

    Current.account = account
    Current.user = default_creator

    # 2. Iterate Files
    files = Dir.glob("#{folder}/*.json")
    puts "Found #{files.count} JSON files."

    files.each do |file_path|
      begin
        data = JSON.parse(File.read(file_path))

        # 3. Process Card
        ActiveRecord::Base.transaction do
          # Find or Create Board (all_access: true so all users can see it)
          board_name = data['board'] || "Imported Board"
          board = Board.find_or_create_by!(name: board_name)
          board.update!(all_access: true) unless board.all_access?

          # Create Card (number is auto-assigned by Card#assign_number callback)
          # We always create new cards to avoid conflicts with internal numbering system
          original_number = data['number']
          status_str = data['status']

          card = board.cards.create!(
            title: data['title'],
            description: data['description'],
            creator: default_creator,
            status: "published"
          )

          # Preserve original timestamps after creation
          card.update_columns(
            created_at: data['created_at'],
            updated_at: data['updated_at'],
            last_active_at: data['updated_at']
          )

          # 4. Attachments
          # Look for folder: #{folder}/#{data['number']}
          attachment_dir = File.join(folder, data['number'].to_s)
          if Dir.exist?(attachment_dir)
            # Find first file
            attachment_files = Dir.glob("#{attachment_dir}/*")
            if attachment_files.any?
              file_to_attach = attachment_files.first
              puts "  Attaching #{File.basename(file_to_attach)} to Card ##{card.number}"
              card.image.attach(io: File.open(file_to_attach), filename: File.basename(file_to_attach))
            end
          end

          # 5. Comments
          if data['comments'].present?
            data['comments'].each do |comment_data|
              # Check if comment already exists (by created_at + card) to avoid dupes?
              # Or just create. Let's just create for now.

              Comment.create!(
                card: card,
                body: comment_data['body'],
                creator: default_creator, # Always use default creator
                created_at: comment_data['created_at'],
                updated_at: comment_data['created_at'] # preserve timestamp
              )
            end
          end

          # If status was "Done", close the card
          if status_str == "Done" && !card.closed?
            card.close
            # Reset updated_at because close touches it
            card.update_column(:updated_at, data['updated_at'])
          end

          puts "Imported Card ##{card.number} (was ##{original_number}): #{card.title}"
        end
      rescue StandardError => e
        puts "Failed to import #{file_path}: #{e.message}"
      end
    end
  end
end
