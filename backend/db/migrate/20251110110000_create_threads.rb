class CreateThreads < ActiveRecord::Migration[7.0]
  def change
    create_table :threads do |t|
      t.references :job, foreign_key: true, type: :bigint
      t.references :contract, foreign_key: true, type: :bigint
      t.timestamps
    end

    # job_id と contract_id は排他的（どちらか一方のみ設定）
    execute <<-SQL
      ALTER TABLE threads ADD CONSTRAINT threads_job_or_contract_check
      CHECK (
        (job_id IS NULL AND contract_id IS NOT NULL) OR
        (job_id IS NOT NULL AND contract_id IS NULL)
      );
    SQL
  end
end
