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

  def suggest(form, value) do
    awesomplete(
      form,
      :profession,
      [
        class: "form-control form-control-lg",
        onfocus: "this.value='';",
        required: true,
        placeholder: 'Essayez "Boulanger"',
        value: value
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

  def render("analytics", %{conn: conn}) do
    dimension1 =
      case conn.remote_ip do
        {109, 26, 209, n} when n >= 86 and n <= 89 -> "true"
        _ -> "false"
      end

    {:safe,
     """
     <!-- Google Optimize -->
     <style>.async-hide { opacity: 0 !important} </style>
     <script>(function(a,s,y,n,c,h,i,d,e){s.className+=' '+y;h.start=1*new Date;
     h.end=i=function(){s.className=s.className.replace(RegExp(' ?'+y),'')};
     (a[n]=a[n]||[]).hide=h;setTimeout(function(){i();h.end=null},c);h.timeout=c;
     })(window,document.documentElement,'async-hide','dataLayer',4000,
     {'GTM-NJL86DT':true});</script>
     <!-- End Google Optimize -->
     <!-- Google Analytics -->
     <script>
     (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
     (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
     m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
     })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

     ga('create', '#{System.get_env("GA_API_KEY")}', 'auto');
     ga('require', '#{System.get_env("GO_TEST_KEY")}');
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

  def render("places", %{tag: tag, prefix: prefix, type: type}) do
    type_requested =
      case type do
        nil -> ""
        _ -> "type: '#{type}',"
      end

    credentials =
      case {System.get_env("ALGOLIA_PLACES_APP_ID"), System.get_env("ALGOLIA_PLACES_API_KEY")} do
        {appId, apiKey} when not is_nil(appId) and not is_nil(apiKey) ->
          """
            appId: '#{appId}',
            apiKey: '#{apiKey}',
          """

        _ ->
          ""
      end

    {:safe,
     """
     <script>
     var placesAutocomplete#{prefix} = places({
       container: document.querySelector('##{prefix}_#{tag}'),
       countries: ['FR'],
       aroundLatLngViaIP: true,
       #{type_requested}
       #{credentials}
       templates: {
         value: function(suggestion) {
           return suggestion.name;
         },
         suggestion: function(suggestion) {
           return suggestion.highlight.name + ' <span class="administrative">' + suggestion.administrative + '</span>';
         }
       }
     });

     var #{prefix}lat = document.querySelector('##{prefix}_lat')
     var #{prefix}lng = document.querySelector('##{prefix}_lng')
     var #{prefix}county = document.querySelector('##{prefix}_county')
     placesAutocomplete#{prefix}.on('change', function(e) {
       #{prefix}lat.value = e.suggestion.latlng.lat;
       #{prefix}lng.value = e.suggestion.latlng.lng;
       #{prefix}county.value = e.suggestion.county || e.suggestion.city || e.suggestion.name;
     });

     placesAutocomplete#{prefix}.on('clear', function() {
       #{prefix}lat.value = "";
       #{prefix}lng.value = "";
       #{prefix}county.value = "";
     });
     </script>
     """}
  end

  def render("places", %{tag: tag, prefix: prefix}) do
    render("places", %{tag: tag, type: nil})
  end

  def render("places", _) do
    render("places", %{prefix: "delegate_search", tag: "address", type: nil})
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
      nil -> "Centre VAE – #{assigns[:certification].label}"
      profession -> "Centre VAE – #{assigns[:certification].label} - #{assigns[:profession]}"
    end
  end

  def complete_page_title(%{view_module: Vae.CertificationView} = assigns) do
    "VAE #{assigns[:profession]}"
  end

  def complete_page_title(%{view_module: Vae.ProfessionView}) do
    "Choisissez votre métier pour obtenir votre diplôme grâce à la VAE"
  end

  def complete_page_title(
        %{view_module: Vae.CertifierView, page: %Scrivener.Page{total_entries: 0}} = assigns
      ) do
    "0 centre VAE pour #{assigns[:certification].label}"
  end

  def complete_page_title(%{view_module: Vae.CertifierView, view_template: "index.html"}) do
    "Centres VAE"
  end

  def complete_page_title(%{view_module: Vae.CertifierView} = assigns) do
    case assigns[:profession] do
      nil -> "Centre VAE – #{assigns[:certification].label}"
      profession -> "Centre VAE – #{assigns[:certification].label} - #{assigns[:profession]}"
    end
  end

  def complete_page_title(%{view_module: Vae.DelegateView, view_template: "show.html"} = assigns) do
    "Parcours VAE #{assigns[:delegate].name}"
  end

  def complete_page_title(%{view_module: Vae.DelegateView}) do
    "Liste des centres de certifications VAE"
  end

  def complete_page_title(_assigns) do
    "Avril | Comment faire une VAE ?"
  end
end
