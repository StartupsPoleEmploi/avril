<template>
  <div class="form">

    <div class="form-fields">

        <div class="field natural-language">
          <span class="title is-5">
            J'ai travaillé du <date-picker v-model="premierePeriode" lang="fr" format="DD/MM/YYYY" confirm></date-picker> au
            <date-picker v-model="secondePeriode" lang="fr" format="DD/MM/YYYY" confirm></date-picker> à <input class="input heure" type="number" v-model="heurePeriode" value="35"> h par semaine.
          </span>
          <div class="">
            <a class="button is-dark" @click="addPeriodes" style="margin-top:1rem">
              + Ajouter cette période
            </a>
          </div>
        </div>

        <div class="columns is-multiline">
          <div v-for="periode in periodes" class="column is-half">
            <div class="box is-equal-height">
              <p class="title is-3">{{ Math.round(periode.totalHeures) }} heures</p>
              <h3 class="title is-6">Du {{ $moment(periode.de) }}</h3>
              <h3 class="title is-6">au {{ $moment(periode.a) }}</h3>
            </div>
          </div>
          <div class="column is-one-quarter">
            <div class="avril__box__experience is-equal-height">
            </div>
          </div>
        </div>

        <div class="field">
          <div class="control">
            <nuxt-link to="precision" class="is-ok button is-text is-pulled-left">
              Remplir plus tard
            </nuxt-link>
            <nuxt-link to="precision" class="is-ok button is-default is-pulled-right">
              Continuer
            </nuxt-link>
          </div>
        </div>

      </div>

      <div class="form-help">
        <h3 class="title is-4">Besoin d'aide ?</h3>
        <div class="form-help-content">
          Nous allons vous aider à calculer le nombre d'heures travaillés. Sélectionnez la date de début et la date de fin de votre contrat ainsi que le nombre d'heures travaillées par semaine. Pour rappel, un temps plein corrrespond à 35 ou 39h par semaine. Si il est indiqué 151h par mois sur votre bulletin de salaire, cela veut dire que vous avez travaillé à temps complet c'est à dire 35h par semaine.
        </div>
        <p style="margin-top:1rem">
          <a href="#" class="is-text">J'ai besoin de plus d'aide</a>
        </p>
      </div>
    </div>
</template>

<script>
import DatePicker from 'vue2-datepicker';
import moment from 'moment';

export default {
  layout: 'experience',
  components: { DatePicker },
  data() {
    return {
      lang: {
        days: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
        months: ['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'],
        pickers: ['7 jours suivants', '30 jours suivants', '7 jours précédents', '30 jours précédents'],
        placeholder: {
          date: 'Sélectionnez une date',
          dateRange: 'Sélectionnez une période'
        }
      },
      time3: '',
      premierePeriode: '',
      secondePeriode: '',
      heurePeriode: '',
      semaine: 46,
      hours: 35,
      selectedYear: 46,
      selectedSemaines: 46,
      selectedHours: 35,
    }
  },
  computed: {
    heures () {
      return this.$store.state.experiences.heures
    },
    periodes () {
      return this.$store.state.experiences.experiences[this.$store.state.experiences.experiences.length - 1].periodes
    },
    pourcentage () {
      if( (this.$store.state.experiences.heures*100)/1607 > 100 )
        return 100
      else
        return (this.$store.state.experiences.heures*100)/1607
    },
  },
  watch: {
    time3(e) {
      this.addPeriode(e)
    }
  },
  created() {
  },

  mounted() {
    // this.$refs.avril__name.focus()
  },
  methods: {
    keymonitor: function(event) {
      if(event.key == "Enter")
      {
        console.log("enter key was pressed!");
        this.$router.push('precision')
      }
    },
    addPeriodes () {
      // TODO: supprimer les weekends du calcul des heures totales

      // par mois, le coeficcient de gain de congé est de 14 :
      // exemple, à 35h / 14 = 2,5 jours par mois de congé
      // exemple, à 10h / 14 = 0,71 jours par mois

      let a = moment(this.premierePeriode);
      let b = moment(this.secondePeriode);
      let periode = {
        de: this.premierePeriode,
        a: this.secondePeriode,
        heures: parseInt(this.heurePeriode),
        jours: b.diff(a, 'days'),
        semaines: b.diff(a, 'week')
      };
      let hJour = parseInt(this.heurePeriode)/5; // 35/5
      let weekends = (b.diff(a, 'days') / 7)*2;

      let joursTravailles = b.diff(a, 'days') - weekends;

      let heuresTravailles = hJour * joursTravailles;

      let totalHeures = heuresTravailles;

      periode.totalHeures = totalHeures;

      this.$store.commit('experiences/addPeriodes', periode)
      this.$store.commit('experiences/addHours', periode.totalHeures)

      this.premierePeriode = '';
      this.secondePeriode = '';
      this.heurePeriode = '';
    },
    addPeriode (e) {
      this.$store.commit('experiences/addPeriode', e)
    },
    addDuree (e) {
      this.$store.commit('experiences/addDuree', e)
    },
  }
}
</script>

<style>
.mx-datepicker-range {
  width: 100%;
}
</style>
