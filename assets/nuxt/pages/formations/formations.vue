<template>
  <div class="form">

    <div class="form-fields">

      <div class="field">
        <h3 class="title is-5">Si vous avez suivi des formation, effectué des stages ou obtenu des habilitations, indiquez les.</h3>
      </div>

      <div class="field">
        <div class="control">
          <input class="input" ref="avril__name" type="text" placeholder="Exemple : CACES, BTS MUC" @keyup.enter="addFormationsContinues">
          <a class="button is-dark is-pulled-right" @click="addFormationsContinues" style="margin-top:4px">
            + Ajouter
          </a>
          <div class="push-enter is-pulled-right" style="margin-top:5px; margin-left:6px;">
            Pour ajouter, appuyez sur <strong>Entrée</strong> ou
          </div>
        </div>
      </div>

      <div class="field">
        <div class="formations">
          <div v-for="formationsContinue in formationsContinues">
            <span class="box">{{formationsContinue}}</span>
          </div>
        </div>
      </div>

      <div class="field">
        <div class="control">
          <nuxt-link v-if="displayNextButton" to="/experiences/fonction" class="is-ok button is-default is-pulled-right">
            Continuer
          </nuxt-link>
          <nuxt-link v-else to="/experiences/fonction" class="is-ok button is-default is-pulled-right">
            Aucun, continuer
          </nuxt-link>
          <nuxt-link to="/experiences/fonction" class="is-ok button is-text is-pulled-left">
            Remplir plus tard
          </nuxt-link>
        </div>
      </div>

    </div>


    <div class="form-help">
      <h3 class="title is-4">Besoin d'aide ?</h3>
      <div class="form-help-content">
Il faut indiquer les stages ou les formations qui ont un lien avec votre projet de diplôme actuel. Si vous n'êtes pas sûr de vous, remplissez cette rubrique au maximum, nous ferons le tri ! Rappelez-vous, ce n'est pas une condition pour valider votre demande, ces renseignements nous aident simplement à mieux vous connaitre. La seule condition requise pour démarrer votre projet reste d'avoir 1 an d'expérience.      </div>
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
  computed: {
    formationsContinues () {
      let act = _.cloneDeep(this.$store.state.experiences.formationsContinues)
      return act.reverse()
    },
    displayNextButton () {
      if( this.$store.state.experiences.formationsContinues.length > 0 )return true;
      return false;
    },
  },
  mounted() {
    this.$store.commit('application/enableFormationStepper')
    this.$store.commit('application/disableExperienceStepper')
    this.$store.commit('application/changeTab', 1)
  },
  methods: {
    addFormations (e) {
      this.$store.commit('experiences/addFormations', e.target.value)
    },
    addFormationsContinues (e) {
      if( this.$refs.avril__name.value == '' || this.$refs.avril__name.value == ' ' ){
        return false;
      }
      this.$store.commit('application/enableMonDossier')
      this.$store.commit('experiences/addFormationContinue', this.$refs.avril__name.value)
      this.$refs.avril__name.value = ''
    },
  }
}
</script>

<style>
.formations {
    /* margin-top: 4rem; */
}
</style>
