#!/bin/bash

export COMPOSE_INTERACTIVE_NO_CLI=1

CONTAINER_ID=${1?"CONTAINER_ID required"}
BUCKET_NAME=${2?"BUCKET_NAME required"}

update_file_url() {
  RESUME_ID=${1?"RESUME_ID required"}
  FILENAME=${2?"FILENAME required"}

read -r -d '' ELIXIR_UPDATE_COMMAND << EOM
resume = Vae.Repo.get(Vae.Resume, $RESUME_ID) |> Vae.Repo.preload(:application)
resume
|> Vae.Resume.changeset(%{url: String.replace(resume.url, resume.filename, "$FILENAME")})
|> Vae.Repo.update()
EOM

  docker exec $CONTAINER_ID mix run -e "$ELIXIR_UPDATE_COMMAND"
}

get_filename() {
  RESUME_ID=${1?"RESUME_ID required"}
  APPLICATION_ID=${2?"APPLICATION_ID required"}
  MODIFICATION_TIME=${3?"MODIFICATION_TIME required"}

  COMMAND="ls -Al -t --full-time /data/$BUCKET_NAME/$APPLICATION_ID | grep '$MODIFICATION_TIME' | head -n 1 | rev | cut -d' ' -f1 | rev"

  docker-compose exec -T minio sh -c "mkdir -p /data/$BUCKET_NAME/$APPLICATION_ID"
  FILENAME=$(docker-compose exec -T minio sh -c "$COMMAND");
  FILENAME=${FILENAME//[$'\t\r\n']}

  if [[ ! -z "$FILENAME" ]]; then
    echo "found !"
    echo ":) $FILENAME found for resume ID: $RESUME_ID"
    update_file_url "$RESUME_ID" "$FILENAME";
  else
    echo ":( File not found for resume ID: $RESUME_ID"
  fi
}

read -r -d '' ELIXIR_SELECT_COMMAND << EOM
import Ecto.Query

date = ~N[2020-05-14 22:51:44]
query = from r in Vae.Resume, where: r.id >= ^9244

Vae.Repo.all(query) |> Enum.each(fn r ->
  unless Regex.match?(~r/[0-9a-f]{32}\.[a-zA-Z]+/, "6ae2d0080fc24720a5bb8264235d18a2.PDF") do
    IO.write("|")
    r.id
    |> Integer.to_string()
    |> String.replace_suffix("", "|")
    |> IO.write()

    r.application_id
    |> Integer.to_string()
    |> String.replace_suffix("", "|")
    |> IO.write()

    r.inserted_at
    |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
    |> String.replace_suffix("", "\n")
    |> IO.write()
  end
end)
EOM


docker exec $CONTAINER_ID mix run -e "$ELIXIR_SELECT_COMMAND" | while read RESUME_INFOS; do
  RESUME_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f2)
  APPLICATION_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f3)
  MODIFICATION_TIME=$(echo $RESUME_INFOS | cut -d '|' -s -f4)

  if [[ ! -z "$RESUME_ID" ]] && [[ ! -z "$APPLICATION_ID" ]] && [[ ! -z "$MODIFICATION_TIME" ]]; then
    echo "Searching for : resume ID: $RESUME_ID app_id: $APPLICATION_ID modif_time: $MODIFICATION_TIME";
    get_filename "$RESUME_ID" "$APPLICATION_ID" "$MODIFICATION_TIME";
  fi
done

# get_filename "9837" "27818" "2020-05-27 16:45:16"