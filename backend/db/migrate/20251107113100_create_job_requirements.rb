class CreateJobRequirements < ActiveRecord::Migration[7.0]
  def change
    create_table :job_requirements do |t|
      t.references :job, null: false, foreign_key: true, type: :bigint
      t.string :kind, null: false
      t.bigint :ref_id, null: false
      t.timestamps
    end

    add_index :job_requirements, [:job_id, :kind, :ref_id], unique: true, name: 'index_job_requirements_unique'
  end
end
