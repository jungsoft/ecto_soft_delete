defmodule Ecto.SoftDelete.Query do
  @moduledoc """
  functions for querying data that is (or is not) soft deleted
  """

  import Ecto.Query

  @doc """
  Returns a query that searches only for undeleted items

      query = from(u in User, select: u)
      |> with_undeleted

      results = Repo.all(query)

  """
  @spec with_undeleted(Ecto.Queryable.t) :: Ecto.Queryable.t
  def with_undeleted(query) do
    if has_include_deleted_at_clause?(query) || !soft_deletable?(query) do
      query
    else
      query
      |> where([t], is_nil(t.deleted_at))
    end
  end

  # Checks the query to see if it contains a where not is_nil(deleted_at)
  # if it does, we want to be sure that we don't exclude soft deleted records
  def has_include_deleted_at_clause?(%Ecto.Query{wheres: wheres}) do
    Enum.any?(wheres, fn %{expr: expr} ->
      expr == {:not, [], [{:is_nil, [], [{{:., [], [{:&, [], [0]}, :deleted_at]}, [], []}]}]}
    end)
  end

  @doc """
  Returns `true` if the query is soft deletable, `false` otherwise.

      query = from(u in User, select: u)
      |> soft_deletable?

  """
  @spec soft_deletable?(Ecto.Queryable.t) :: boolean()
  def soft_deletable?(query) do
    schema_module = get_schema_module(query)
    fields = if schema_module, do: schema_module.__schema__(:fields), else: []

    Enum.member?(fields, :deleted_at)
  end

  defp get_schema_module({_raw_schema, module}) when not is_nil(module), do: module
  defp get_schema_module(%Ecto.Query{from: %{source: source}}), do: get_schema_module(source)
  defp get_schema_module(%Ecto.SubQuery{query: query}), do: get_schema_module(query)
  defp get_schema_module(_), do: nil
end
