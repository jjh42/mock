defmodule MyApp.IndirectMod do

  def value do
    1
  end

  def indirect_value do
    value()
  end

  def indirect_value_2 do
    MyApp.IndirectMod.value()
  end

end
