class CreateDisputeEvidences < ActiveRecord::Migration[7.0]
  def change
    create_table :dispute_evidences do |t|
      t.integer :dispute_id, null: false
      t.integer :submitted_by_id, null: false
      t.string :evidence_type, null: false
      t.string :file_url
      t.text :description
      t.string :content_hash
      t.integer :file_size_bytes
      t.string :mime_type
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :dispute_evidences, :dispute_id
    add_index :dispute_evidences, :submitted_by_id
    add_foreign_key :dispute_evidences, :disputes
    add_foreign_key :dispute_evidences, :users, column: :submitted_by_id
  end
end
