defmodule Paddle.Attributes do
  @moduledoc ~S"""
  Module used internally by Paddle to manipulate / convert LDAP attributes.
  """

  @doc ~S"""
  
  """
  def get(class_object) do
    given_attributes = Map.from_struct(class_object)
    generated_attributes = generate_defaults(class_object)

    attributes = Map.merge(generated_attributes, given_attributes,
                           &choose_value/3)

    required_attributes = Paddle.Class.required_attributes(class_object)

    missing_req_attributes = get_missing_req(attributes, required_attributes)
    case missing_req_attributes do
      [] -> {:ok, attributes}
      _ -> {:error, :missing_required_attributes, missing_req_attributes}
    end
  end

  defp generate_defaults(class_object) do
    for {attribute, func} <- Paddle.Class.generators(class_object), into: %{} do
      {attribute, func.(class_object)}
    end
    |> Map.merge(%{objectClass: Paddle.Class.object_classes(class_object)})
  end

  defp choose_value(_key, generated_value, given_value) do
    case given_value do
      nil -> generated_value
      _ -> given_value
    end
  end

  defp get_missing_req(attributes, required_attributes) do
    attributes
    |> Enum.filter_map(fn {attribute, value} ->
      attribute in required_attributes and value == nil
    end,
    fn {attribute, _value} -> attribute end)
  end

end
