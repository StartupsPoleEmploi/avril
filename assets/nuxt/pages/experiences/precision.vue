<template>
  <div class="form">

    <div class="form-fields">

      <div class="field">
        <div class="control">
          <label class="label">Qu'avez-vous fait dans votre métier ?</label>
          <input class="input" ref="avril__name" type="text" placeholder="Exemple : Pétrissage du pain" @keyup.enter="addActivite">
          <a class="button is-default is-pulled-right" @click="addActivite" style="margin-top:4px">
            + Ajouter
          </a>
          <div class="push-enter is-pulled-right" style="margin-top:5px; margin-left:6px;">
            Appuyez sur <strong>Entrée</strong> pour ajouter cette activité ou
          </div>
        </div>
      </div>

      <div class="field">
        <div class="activites">
          <div v-for="activite in activites">
            <span class="box">{{activite}}</span>
          </div>
        </div>
      </div>
      <div class="field" v-if="heures >= 1607">
        <div class="control">
          <nuxt-link to="/formations" class="is-ok button is-text is-pulled-left">
            Remplir plus tard
          </nuxt-link>
        </div>
      </div>

      <div class="field" v-if="heures < 1607">
        <div class="control">
          <nuxt-link to="/experiences" class="is-ok button is-text is-pulled-left">
            Remplir plus tard
          </nuxt-link>
          <nuxt-link to="/experiences" class="is-ok button is-dark is-pulled-right">
            Continuer
          </nuxt-link>
        </div>
      </div>
    </div>

      <div class="form-help">
        <h3 class="title is-4">Besoin d'aide ?</h3>
        <p>
          Pour aider le certificateur à bien comprendre quel a été votre rôle au sein de [entreprise], vous devez indiquer une liste de tâche que vous avez
          effectué au quotidien.
        </p>
        <p>Voici une liste d'activité pour vous aider. Vous pouvez les ajouter ou en créer une nouvelle.</p>
        <br/>
        <div class="form-help-ativites">
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Déterminer les mesures d’hygiène, de santé et de mise en sécurité
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Définir les besoins
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Collecter, traiter et organiser l’information – proposer et argumenter
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Préparer les espaces de travail
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Identifier les éléments de la qualité
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Détecter les anomalies
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Préparer les espaces de travail
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Mettre en oeuvre des mesures d’hygiène
          </a>
          <a class="box" v-on:click="addExp">
            <input type="radio" name="answer"> &nbsp;Réceptionner, stocker
          </a>
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
  components: {},
  computed: {
    activites () {
      let act = _.cloneDeep(this.$store.state.experiences.experiences[this.$store.state.experiences.experiences.length - 1].activities)
      return act.reverse()
    },
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
    this.$store.commit('experiences/addHours')
  },
  mounted() {
    this.$refs.avril__name.focus()
    this.$store.commit('application/disableFormationStepper')
  },
  methods: {
    addPrecision (e) {
      this.$store.commit('experiences/addPrecision', e.target.value)
    },
    addActivite (e) {
      if( this.$refs.avril__name.value == '' || this.$refs.avril__name.value == ' ' ){
        return false;
      }
      this.$store.commit('experiences/addActivite', this.$refs.avril__name.value)
      this.$refs.avril__name.value = '';
      return false;
    },
    addExp (e) {
      this.$store.commit('experiences/addActivite', e.target.outerText.trim());
      e.target.remove()
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
  }
}
</script>

<style>
.activites{
  margin-top: 4rem;
}
.box{
  /* margin-top: 1rem; */
}
.mx-datepicker-range {
  width: 100%;
}
.form-help-ativites{
  height: 60%;
  padding: 1rem;
  overflow: auto;
}
</style>
