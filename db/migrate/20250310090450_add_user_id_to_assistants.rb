class AddUserIdToAssistants < ActiveRecord::Migration[8.0]
  def change
    add_reference :assistants, :user, null: false, foreign_key: true
    add_reference :assistants, :last_used_assistant, null: false, foreign_key: true
    add_column :assistants, :title, :string
    add_column :assistants, :instructions, :text
    add_column :assistants, :tool_choice, :string
    add_column :assistants, :tools, :json
  end
end
