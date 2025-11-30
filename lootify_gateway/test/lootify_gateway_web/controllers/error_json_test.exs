defmodule LootifyGatewayWeb.ErrorJSONTest do
  use LootifyGatewayWeb.ConnCase, async: true

  test "renders 404" do
    assert LootifyGatewayWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert LootifyGatewayWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
