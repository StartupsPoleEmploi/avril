<template>
  <div class="form">

    <div class="form-fields">

        <!-- <div class="field">
          <label class="label">Durée totale exprimée en heures</label>
          <div class="control">
            <input ref="avril__name" class="input" type="number" placeholder="Exemple : 1300" @input="addDuree">
          </div>
        </div> -->

        <div class="field natural-language">
          <span class="title is-5">
            J'ai travaillé pendant
          </span>
          <span class="select years">
            <select>
              <option>1 année</option>
              <option>2 années</option>
              <option>3 années</option>
              <option>plus de 3 années</option>
            </select>
          </span>
          <span class="title is-5">
            à
          </span>
          <span class="select hours">
            <select>
              <option>35 heures</option>
              <option>plus de 35 heures</option>
              <option>entre 25 et 34 heures</option>
              <option>entre 15 et 24 heures</option>
              <option>moins de 15 heures</option>
            </select>
          </span>
          <span class="title is-5">
            par semaine
          </span>

        </div>

        <div class="field">
          <label class="label">Sur quelle période ?</label>
          <date-picker v-model="time3" range lang="fr" format="DD/MM/YYYY" confirm></date-picker>
        </div>

        <div class="field">
          <div class="control">
            <nuxt-link to="precision" class="is-ok button is-text is-pulled-left">
              Remplir plus tard
            </nuxt-link>
            <nuxt-link to="precision" class="is-ok button is-dark is-pulled-right">
              Continuer
            </nuxt-link>
          </div>
        </div>

      </div>


      <div class="form-help">
        <h3 class="title is-4">Besoin d'aide ?</h3>
        <div class="form-help-content">
          Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        </div>
        <p style="margin-top:1rem">
          <a href="#" class="is-text">J'ai besoin de plus d'aide</a>
        </p>
      </div>
    </div>
</template>

<script>
import DatePicker from 'vue2-datepicker';

// import Logo from '~/components/Logo.vue'
// const ioHook = require('iohook');
export default {
  layout: 'experience',
  components: { DatePicker },
  data() {
    return {
      lang: {
        days: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'],
        months: ['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'],
        pickers: ['7 jours suivants', '30 jours suivanst', '7 jours précédents', '30 jours précédents'],
        placeholder: {
          date: 'Sélectionnez une date',
          dateRange: 'Sélectionnez une période'
        }
      },
      time3: '',
    }
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
    // this.$refs.avril__name.focus()
  },
  methods: {
    keymonitor: function(event) {
      // console.log(event.key);
      if(event.key == "Enter")
      {
        console.log("enter key was pressed!");
        // this.$router.push('/name')
        this.$router.push('precision')
      }
    },
    addPeriode (e) {
      this.$store.commit('experiences/addPeriode', '20-04-2010, 23-07-2018')
    },
    addDuree (e) {
      this.$store.commit('experiences/addDuree', parseInt(e.target.value))
    },
  }
}
</script>

<style>
.mx-datepicker-range {
  width: 100%;
}
</style>
