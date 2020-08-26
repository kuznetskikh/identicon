defmodule Identicon do
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def hash_input(input) do
    %Identicon.Image{
      hex:
        :crypto.hash(:md5, input)
        |> :binary.bin_to_list()
    }
  end

  def pick_color(%Identicon.Image{hex: [r, g, b | _]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  def build_grid(%Identicon.Image{hex: hex} = image) do
    %Identicon.Image{
      image
      | grid:
          hex
          |> Enum.chunk_every(3, 3, :discard)
          |> Enum.map(&mirror_row/1)
          |> List.flatten()
          |> Enum.with_index()
    }
  end

  def mirror_row([first, second | _] = row) do
    row ++ [second, first]
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    %Identicon.Image{
      image
      | grid:
          Enum.filter(grid, fn {code, _} ->
            rem(code, 2) === 0
          end)
    }
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    %Identicon.Image{
      image
      | pixel_map:
          Enum.map(grid, fn {_, index} ->
            horizontal = rem(index, 5) * 50
            vertical = div(index, 5) * 50

            {{horizontal, vertical}, {horizontal + 50, vertical + 50}}
          end)
    }
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {left_top, right_bottom} ->
      :egd.filledRectangle(image, left_top, right_bottom, fill)
    end)

    :egd.render(image)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end
end
