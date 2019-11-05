<template>
  <div class="form">

    <div class="form-fields">

        <h3 class="title is-5">A quelle famille professionnelle appartient votre métier ?</h3>

        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Administration publique, professions juridiques, armée et police
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('A')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Agriculture, marine, pêche
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Artisanat
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Banque et assurance
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('B')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Bâtiment, travaux publics
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Commerce
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Communication, information, art et spectacle
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('C')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Electricité, électronique
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Enseignement, formation
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Études et recherche
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Gestion, administration des entreprises
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('E')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Industries de process
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Informatique et télécommunications
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Ingénieurs et cadres de l'industrie
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Hôtellerie, restauration, alimentation
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('F')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Maintenance
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('G')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Matériaux souples, bois, industries graphiques
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('D')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Mécanique, travail des métaux
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Politique, religion
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Santé, action sociale, culturelle et sportive
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Services aux particuliers et aux collectivités
        </nuxt-link>
        <nuxt-link v-on:click.native="addFamille('H')" to="status" class="box">
          <input type="radio" name="answer"> &nbsp;Transports, logistique et tourisme
        </nuxt-link>


        <div class="form-field-action field" style="margin-top: 20px">
          <div class="control">
            <nuxt-link v-on:click.native="addFamille('H')" to="status" class="is-ok button is-text is-pulled-left">
              Remplir plus tard
            </nuxt-link>
          </div>
        </div>

      </div>


      <div class="form-help">
        <h3 class="title is-4">Besoin d'aide ?</h3>
        <div class="form-help-content">
          Il s'agit de cocher la case de la bonne famille de métier, celle de votre métier. Par exemple, si vous avez été secrétaire, la famille métier sera "gestion, administration des entreprises".
Les familles professionnelles sont des ensembles de métiers qui ont des points communs comme des activités ou des compétences.        </div>
        <p style="margin-top:1rem">
          <a href="#" class="is-text">J'ai besoin de plus d'aide</a>
        </p>
      </div>
    </div>
</template>

<script>
// import Logo from '~/components/Logo.vue'
// const ioHook = require('iohook');
export default {
  layout: 'experience',
  components: {
    // Logo
  },
  computed: {
    heures () {
      return this.$store.state.experiences.heures
    },
    pourcentage () {
      if( (this.$store.state.experiences.heures*100)/1607 > 100 )
        return 100
      else
        return (this.$store.state.experiences.heures*100)/1607
    }
  },

  created() {
    // console.log('accueil created')
  },

  mounted() {

  },
  methods: {
    addFamille (e) {
      this.$store.commit('experiences/addFamille', e)
    },
  }
}
</script>

<style>

</style>
