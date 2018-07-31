defmodule Vae.ComponentView do
  use Vae.Web, :view

  import PhoenixFormAwesomplete

  def suggest_clean do
    script("""
      var accents = "ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž",
      accentsOut = "AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz",
      accentsIndex = function(str) { return accents.indexOf(str) },
      removeAccents = function(str) {
        str = str.split('');
        var strLen = str.length;
        var i, x;
        for (i = 0; i < strLen; i++) {
          if ((x = accentsIndex(str[i])) != -1) {
            str[i] = accentsOut[x];
          }
        }
        return str.join('');
      },
      filterWords = function(data, input) {
        return data;
      },
      itemWords = function(text, input) {
        var clean_text = text.replace(/[-]/g, " "),
        clean_input = input.replace(/[-]/g, " ");

        if(accentsIndex(input) != -1)
          text = AwesompleteUtil.mark(removeAccents(clean_text), removeAccents(clean_input));
        else
          text = AwesompleteUtil.mark(clean_text, clean_input);

        return AwesompleteUtil.item(text, input);
      };
    """)
  end

  def suggest(form, position) do
    awesomplete(
      form,
      :profession,
      [
        class: suggest_class(position),
        onfocus: "this.value='';",
        placeholder: "Pour quel métier souhaitez-vous un diplôme ?",
        required: true
      ],
      %{
        url: "/professions/_suggest?search[for]=",
        value: "value",
        limit: 4,
        autoFirst: true,
        filter: "filterWords",
        item: "itemWords",
        sort: false
      }
    )
  end

  defp suggest_class(:home), do: "form-control form-control-lg"
  defp suggest_class(_), do: "form-control mr-sm-2"

  def render("analytics", %{conn: conn}) do
    dimension1 =
      case conn.remote_ip do
        {109, 26, 209, n} when n >= 86 and n <= 89 -> "true"
        _ -> "false"
      end

    {:safe,
     """
     <!-- Google Analytics -->
     <script>
     (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
     (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
     m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
     })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

     ga('create', '#{System.get_env("GA_API_KEY")}', 'auto');
     ga('set', 'dimension1', '#{dimension1}');
     ga('send', 'pageview');
     </script>
     <!-- End Google Analytics -->
     """}
  end

  def render("hotjar", _) do
    {:safe,
     """
     <!-- Hotjar Tracking Code for http://avril.pole-emploi.fr -->
     <script>
     (function(h,o,t,j,a,r){
     h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
     h._hjSettings={hjid:#{System.get_env("HOTJAR_ID")},hjsv:5};
     a=o.getElementsByTagName('head')[0];
     r=o.createElement('script');r.async=1;
     r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
     a.appendChild(r);
     })(window,document,'//static.hotjar.com/c/hotjar-','.js?sv=');
     </script>
     """}
  end

  def render("places", _) do
    {app_id, api_key} = Vae.Places.LoadBalancer.get_index_credentials()

    {:safe,
     """
     <script>
     var placesAutocomplete = places({
       container: document.querySelector('#delegate_search_address'),
       countries: ['FR'],
       aroundLatLngViaIP: true,
       appId: "#{app_id}",
       apiKey: "#{api_key}"
     });

     var $lat = document.querySelector('#delegate_search_lat')
     var $lng = document.querySelector('#delegate_search_lng')
     placesAutocomplete.on('change', function(e) {
       $lat.value = e.suggestion.latlng.lat;
       $lng.value = e.suggestion.latlng.lng;
       document.querySelector('#delegate_form').submit()
     });

     placesAutocomplete.on('clear', function() {
       $lat.value = undefined;
       $lng.value = undefined;
     });
     </script>
     """}
  end

  @title_suffix " | Avril - un service Pôle emploi"

  def suffix(title) do
    title <> @title_suffix
  end

  def page_title(assigns) do
    complete_page_title(assigns)
    |> suffix()
  end

  def complete_page_title(
        %{view_module: Vae.CertificationView, page: %Scrivener.Page{total_entries: 0}} = assigns
      ) do
    "0 diplôme de #{assigns[:profession]}"
  end

  def complete_page_title(
        %{view_module: Vae.CertificationView, view_template: "show.html"} = assigns
      ) do
    case assigns[:profession] do
      nil -> "Centre V.A.E – #{assigns[:certification].label}"
      profession -> "Centre V.A.E – #{assigns[:certification].label} - #{assigns[:profession]}"
    end
  end

  def complete_page_title(%{view_module: Vae.CertificationView} = assigns) do
    "V.A.E #{assigns[:profession]}"
  end

  def complete_page_title(%{view_module: Vae.ProfessionView}) do
    "Choisissez votre métier pour obtenir votre diplôme grâce à la V.A.E"
  end

  def complete_page_title(
        %{view_module: Vae.CertifierView, page: %Scrivener.Page{total_entries: 0}} = assigns
      ) do
    "0 centre V.A.E pour #{assigns[:certification].label}"
  end

  def complete_page_title(%{view_module: Vae.CertifierView, view_template: "index.html"}) do
    "Centres V.A.E"
  end

  def complete_page_title(%{view_module: Vae.CertifierView} = assigns) do
    case assigns[:profession] do
      nil -> "Centre V.A.E – #{assigns[:certification].label}"
      profession -> "Centre V.A.E – #{assigns[:certification].label} - #{assigns[:profession]}"
    end
  end

  def complete_page_title(%{view_module: Vae.DelegateView, view_template: "show.html"} = assigns) do
    "Parcours V.A.E #{assigns[:delegate].name}"
  end

  def complete_page_title(%{view_module: Vae.DelegateView}) do
    "Liste des centres de certifications V.A.E"
  end

  def complete_page_title(_assigns) do
    "Avril | Comment faire une V.A.E ?"
  end
end
