class AddStatusToKnowledgeEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledge_entries, :status, :string, default: "pending"
    add_column :knowledge_entries, :processed_at, :datetime
    add_column :knowledge_entries, :metadata, :jsonb, default: {}
  end
end
