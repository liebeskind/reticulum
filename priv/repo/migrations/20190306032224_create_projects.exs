defmodule Ret.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, prefix: "ret0", primary_key: false) do
      add(:project_id, :bigint, default: fragment("ret0.next_id()"), primary_key: true)
      add(:project_sid, :string)
      add(:name, :string, null: false)
      add(:created_by_account_id, references(:accounts, column: :account_id), null: false)
      add(:project_owned_file_id, :bigint, null: true)
      add(:thumbnail_owned_file_id, :bigint, null: true)

      timestamps()
    end

    create(index(:projects, [:project_sid], unique: true))
    create(index(:projects, [:created_by_account_id]))
  end
end
