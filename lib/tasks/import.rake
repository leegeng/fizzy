namespace :import do
  desc "Import cards from JSON files in a folder"
  task cards: :environment do |t, args|
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

    default_creator = User.first
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
          # Find or Create Board
          board_name = data['board'] || "Imported Board"
          board = Board.find_or_create_by!(name: board_name)

          # Create Card
          # Check if card with this number already exists to avoid duplicates/errors if running multiple times
          # Note: Card numbers are usually auto-incrementing, so forcing a number might require skipping validations or careful handling.
          # However, Card#assign_number uses ||= so if we set it, it should respect it.

          card = Card.find_or_initialize_by(number: data['number'], board: board)

          # Map Status if needed.
          # JSON "Done" -> internal status.
          # Card statuses are typically: open, closed.
          # If existing logic uses specific buckets, we might need to map.
          # Assuming "Done" maps to 'closed' or just a column.
          # For simplicity, we import as-is into title/description and let the user sort it,
          # or try to map 'Done' to closed.

          status_str = data['status']
          # If status is 'Done', we might want to close it?
          # Or just put it in a column named 'Done'?
          # Let's try to put it in a column if possible, or leave it.

          card.update!(
            title: data['title'],
            description: data['description'],
            created_at: data['created_at'],
            updated_at: data['updated_at'],
            creator: default_creator,
            # We don't forcefully set status because Card state is complex (triage, etc.)
            # But if it is 'Done', maybe we close it?
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

          # Extra: If status was "Done", maybe close the card?
          if status_str == "Done" && !card.closed?
             card.close
             # Reset updated_at because close touches it
             card.update_column(:updated_at, data['updated_at'])
          end

          puts "Imported Card ##{card.number}: #{card.title}"
        end
      rescue StandardError => e
        puts "Failed to import #{file_path}: #{e.message}"
      end
    end
  end
end
