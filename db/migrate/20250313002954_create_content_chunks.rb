class CreateContentChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :content_chunks do |t|
      t.text :content, null: false
      t.integer :sequence, null: false
      t.json :metadata, null: false, default: {}
      t.references :knowledge_entry, null: false, foreign_key: true, index: true

      t.timestamps

      t.index :sequence
    end
  end
end
