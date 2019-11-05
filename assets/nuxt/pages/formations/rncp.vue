<template>
  <div class="form">

    <div class="form-fields">

      <div class="field">
        <h3 class="title is-5">Avez vous déjà un diplôme ou une partie d'un diplôme en rapport avec celui que vous souhaitez obtenir aujourd'hui ?</h3>
      </div>

      <div class="field">
        <div class="control">
          <input class="input" ref="avril__name" type="text" placeholder="Exemple : Bac pro commerce" @keyup.enter="addTitre">
          <a class="button is-dark is-pulled-right" @click="addTitre" style="margin-top:4px">
            + Ajouter
          </a>
          <div class="push-enter is-pulled-right" style="margin-top:5px; margin-left:6px;">
            Pour ajouter, appuyez sur <strong>Entrée</strong> ou
          </div>
        </div>
      </div>

      <div class="field">
        <div class="titres">
          <div v-for="titre in titres">
            <span class="box">{{titre}}</span>
          </div>
        </div>
      </div>

      <div class="field">
        <div class="control">
          <nuxt-link v-if="displayNextButton" to="formations" class="is-ok button is-default is-pulled-right">
            Continuer
          </nuxt-link>
          <nuxt-link v-else to="formations" class="is-ok button is-default is-pulled-right">
            Aucun, continuer
          </nuxt-link>
          <nuxt-link to="formations" class="is-ok button is-text is-pulled-left">
            Remplir plus tard
          </nuxt-link>
        </div>
      </div>

    </div>


    <div class="form-help">
      <h3 class="title is-4">Besoin d'aide ?</h3>
      <div class="form-help-content">
Indiquez nous ici les diplômes ou les parties de diplômes que vous avez déjà obtenus.
Par exemple : Diplôme "CAP petite enfance" obtenu ou bloc de compétences "Conduite d'un projet RH" obtenu.
Ces informations serviront aux certificateurs et aux accompagnateurs de votre projet de diplôme en VAE à mieux vous conseiller.
Ne vous inquiétez pas, il s'agit d'une simple information, cela ne sert pas à évaluer votre candidature à la VAE.
Rappelez-vous, la seule condition pour demander votre diplôme en VAE est de justifier d'un an d'expérience.
      </div>
      <p style="margin-top:1rem">
        <a href="#" class="is-text">J'ai besoin de plus d'aide</a>
      </p>
    </div>
  </div>
</template>

<script>
import _ from 'lodash';

export default {
  layout: 'experience',
  components: {
    // Logo
  },
  computed: {
    titres () {
      let act = _.cloneDeep(this.$store.state.experiences.titres)
      return act.reverse()
    },
    displayNextButton () {
      if( this.$store.state.experiences.titres.length > 0 )return true;
      return false;
    },
  },
  mounted() {
    // this.$store.commit('application/addRemplissage', 80)
  },
  methods: {
    addRNCP (e) {
      this.$store.commit('experiences/addRNCP', e.target.value)
    },
    addTitre (e) {
      if( this.$refs.avril__name.value == '' || this.$refs.avril__name.value == ' ' ){
        return false;
      }
      this.$store.commit('experiences/addTitre', this.$refs.avril__name.value)
      this.$refs.avril__name.value = ''
    },
  }
}
</script>

<style>
.titres {
    /* margin-top: 4rem; */
}
</style>
