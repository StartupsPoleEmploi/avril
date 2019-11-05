<template>

  <div class="form">

    <div class="form-fields">

        <h3 class="title is-5">Statut au moment où vous avez exercé votre activité</h3>

        <nuxt-link v-on:click.native="addStatus('A')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;Salarié
        </nuxt-link>
        <nuxt-link v-on:click.native="addStatus('B')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;En contrat de professionnalisation
        </nuxt-link>
        <nuxt-link v-on:click.native="addStatus('C')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;En contrat d’apprentissage
        </nuxt-link>
        <nuxt-link v-on:click.native="addStatus('D')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;Travailleur indépendant, artisan, profession libérale
        </nuxt-link>
        <nuxt-link v-on:click.native="addStatus('E')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;Volontaire
        </nuxt-link>
        <nuxt-link v-on:click.native="addStatus('F')" to="periode" class="box">
          <input type="radio" name="answer"> &nbsp;Autre
        </nuxt-link>


          <div class="form-field-action field" style="margin-top: 20px">
            <div class="control">
              <nuxt-link v-on:click.native="addStatus('H')" to="periode" class="is-ok button is-text is-pulled-left">
                Remplir plus tard
              </nuxt-link>
            </div>
          </div>

      </div>


      <div class="form-help">
        <h3 class="title is-4">Besoin d'aide ?</h3>
        <div class="form-help-content">
          Pour cette expérience, étiez-vous employé par un patron, à votre compte, en formation une partie du temps ? Peu importe le statut, l'important est de prouver que vous avez fait cette activité.
        </div>
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
    keymonitor: function(event) {
      console.log(event.key);
      if(event.key == "Enter")
      {
        console.log("enter key was pressed!");
        // this.$router.push('/name')
        this.$router.push('name')
      }
    },
    addStatus (e) {
      this.$store.commit('experiences/addStatus', e)
    },
  }
}
</script>

<style>

</style>
