#!/bin/bash

export COMPOSE_INTERACTIVE_NO_CLI=1

BUCKET_NAME=${1?"BUCKET_NAME required"}

PHOENIX_CONTAINER_ID=$(docker ps -a | grep phoenix | cut -d' ' -f1)
MINIO_CONTAINER_ID=$(docker ps -a | grep minio | cut -d' ' -f1)

update_file_url() {
  RESUME_ID=${1?"RESUME_ID required"}
  FILENAME=${2?"FILENAME required"}

read -r -d '' ELIXIR_UPDATE_COMMAND << EOM
resume = Vae.Repo.get(Vae.Resume, $RESUME_ID) |> Vae.Repo.preload(:application)
resume
|> Vae.Resume.changeset(%{url: String.replace(resume.url, resume.filename, "$FILENAME")})
|> Vae.Repo.update()
EOM

  docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_UPDATE_COMMAND"
}

get_filename() {
  RESUME_ID=${1?"RESUME_ID required"}
  APPLICATION_ID=${2?"APPLICATION_ID required"}
  MODIFICATION_TIME=${3?"MODIFICATION_TIME required"}

  LIST_FILE_COMMAND="ls -Al -t --full-time /data/$BUCKET_NAME/$APPLICATION_ID | grep '$MODIFICATION_TIME' | rev | cut -d' ' -f1 | rev"

  docker exec $MINIO_CONTAINER_ID sh -c "mkdir -p /data/$BUCKET_NAME/$APPLICATION_ID"
  FILENAME=$(docker exec $MINIO_CONTAINER_ID sh -c "$LIST_FILE_COMMAND");

  if [ $(echo "$FILENAME" | wc -l) -gt 1 ];
  then
    echo ":( Multiple entries, need to manual match for application_id $APPLICATION_ID"
  fi
  FILENAME=${FILENAME//[$'\t\r\n']} # Remove new lines
  if [[ ! -z "$FILENAME" ]]; then
    echo ":) $FILENAME found for resume ID: $RESUME_ID"
    update_file_url "$RESUME_ID" "$FILENAME";
  else
    echo ":( File not found for resume ID: $RESUME_ID"
  fi

}

read -r -d '' ELIXIR_SELECT_COMMAND << EOM
import Ecto.Query

date = ~N[2020-05-14 22:51:44]
query =
  from r in Vae.Resume, [where: not like(r.url, "https://avril.pole-emploi.fr/files/%/________________________________.%"), order_by: [desc: :inserted_at]]

Vae.Repo.all(query) |> Enum.each(fn r ->
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
  |> NaiveDateTime.add(1)
  |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
  |> String.replace_suffix("", "\n")
  |> IO.write()
end)
EOM

docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_SELECT_COMMAND" | while read RESUME_INFOS; do
  RESUME_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f2)
  APPLICATION_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f3)
  MODIFICATION_TIME=$(echo $RESUME_INFOS | cut -d '|' -s -f4)

  if [[ ! -z "$RESUME_ID" ]] && [[ ! -z "$APPLICATION_ID" ]] && [[ ! -z "$MODIFICATION_TIME" ]]; then
    echo "Searching for : resume ID: $RESUME_ID app_id: $APPLICATION_ID modif_time: $MODIFICATION_TIME";
    get_filename "$RESUME_ID" "$APPLICATION_ID" "$MODIFICATION_TIME";
  fi
done

# get_filename "9837" "27818" "2020-05-27 16:45:16";
