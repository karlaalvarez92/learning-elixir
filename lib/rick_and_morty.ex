defmodule RickAndMorty do
  @moduledoc """
  Documentation for `RickAndMorty`.
  """

  @doc """
    api_response hace las llamadas a la API
    Utiliza HTTPotion para manejar las llamadas y Poison para convertirlo a Json
  """
  def api_response(url) when is_binary(url) do
    response = HTTPotion.get url
    Poison.Parser.parse!(response.body)
  end

  @doc """
    Filtra por el status definido en histogram y va coleccionando los encontrados.
    Llama a iterate_pages que hace la llamada a la siguiente pagina de la API, y
    esta sigue llamando a filter hasta que el next url es nil.

    Usé pattern matching para cambiar el comportamiento final una vez que ya no hay más
    páginas para que retorne la colección
  """
  def filter_by_status(collection) do
    collection
  end

  def filter_by_status(response, collection, status) do
    found = Enum.filter(response["results"], fn(character) -> character["status"] == status end)

    collection = collection ++ found
    iterate_pages(response["info"]["next"], status, collection)
  end

  def iterate_pages(nil, _status, collection) do
    filter_by_status(collection)
  end

  def iterate_pages(url, status, collection) when is_binary(url) do
    api_response(url) |> filter_by_status(collection, status)
  end

  @doc """
    Separa por especie, si no encuntra la llave de esa especie llama a add_new_key
    y en caso contrario solo actualiza
  """
  def collect_by_specie([], collect) do
    collect
  end

  def collect_by_specie([head | tail], collect) do
    key = String.to_atom(head["species"])
    if Keyword.has_key?(collect, key ) do
      update_values(key, collect, tail)
    else
      add_new_key(key, collect, tail)
    end
  end

  def add_new_key(key, collect, tail) do
    collect = Keyword.put(collect, key, 0)
    update_values(key, collect, tail)
  end

  def update_values(key, collect, tail) do
    collect =  Keyword.put(collect, key, collect[key] + 1)
    collect_by_specie(tail, collect)
  end

  @doc """
    Toma la colección por especie y el total de characteres y manda llamar
    el build string, el cual se llama a si mismo hasta que no queda nada
    en la collección
  """
  def build_histogram(collection, total_characters) do
    total_deaths = Keyword.values(collection)
    total_deaths = Enum.sum(total_deaths)
    percentage = total_deaths * 100 |> div(total_characters)
    string = ~s/

Total deaths: #{total_deaths}
Total characters: #{total_characters}
#{percentage}% has died

/
    build_string(collection, string)
  end


  def build_string([], string) do
    begining_string= ~s/
Rick and Morty deaths statistics
/
    IO.puts begining_string <> string
  end

  def build_string([head | tail], string) do
    specie = elem(head, 0) |> to_string
    count = elem(head, 1)
    new_string= ~s/
#{specie}: #{count}/
    string = new_string <> string
    build_string(tail, string)
  end

  @doc """
    El método histogram es el que ejecuta todo el módulo
    Manda llamar cada uno de los métodos necesarios pasando los parámetros al método siguiente
  """
  def histogram do
    url = "https://rickandmortyapi.com/api/character"
    status = "Dead"
    collection = []
    total_characters = api_response(url)["info"]["count"]

    api_response(url) |> filter_by_status(collection, status) |> collect_by_specie(collection) |> build_histogram(total_characters)
  end
end
