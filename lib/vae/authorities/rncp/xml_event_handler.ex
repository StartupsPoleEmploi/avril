# defmodule Vae.Authorities.Rncp.XmlEventHandler do
#   @behaviour Saxy.Handler

#   def handle_event(:start_document, prolog, nil) do
#     IO.inspect("Start parsing document")
#     {:ok, nil}
#   end

#   def handle_event(:end_document, _data, nil) do
#     IO.inspect("Finish parsing document")
#     {:ok, nil}
#   end

#   def handle_event(:start_element, {"FICHE", _attributes}, nil) do
#     IO.inspect("Start parsing element FICHE with attributes #{inspect(attributes)}")
#     {:ok, %{
#       fiche: %{},
#     }}
#   end

#   def handle_event(:end_element, {"FICHE", _attributes}, state) do
#     {:ok, nil}
#   end

#   def handle_event(:start_element, {name, _attributes}, %{fiche: fiche}) do
#     IO.inspect(name)
#     {:ok, state}
#   end


#   def handle_event(:start_element, _other_element, state) do
#     {:ok, state}
#   end

#   def handle_event(:end_element, _other_element, state) do
#     {:ok, state}
#   end

#   def handle_event(:characters, chars, state) do
#     {:ok, state}
#   end
# end