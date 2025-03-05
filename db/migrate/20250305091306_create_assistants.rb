class CreateAssistants < ActiveRecord::Migration[8.0]
  def change
    create_table :assistants do |t|
      t.string :title, null: false
      t.string :instructions
      t.string :tool_choice
      t.json :tools
      t.timestamps
      t.references :user, null: true, foreign_key: true
    end
  end
end
