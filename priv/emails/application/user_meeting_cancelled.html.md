[SUJET]: # (<%= @username %>, votre réunion d'information a été annulée)

Bonjour <%= @username %>,

Nous vous informons que notre partenaire <%= @source %> a annulé la réunion du
<%= Timex.format!(@meeting.start_date, @date_format, :strftime) %> à <%= @meeting.place %> que vous aviez sélectionnée.

Nous vous invitons à retourner sur [Avril](<%= @url %>) afin de vous positionner sur une prochaine réunion.

Avril vous souhaite le succès pour votre projet VAE !

L'équipe Avril