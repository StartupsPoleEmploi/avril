<template>
  <div class="form">
    <div class="form-fields">
      <h1 class="title is-3">Dernière question !</h1>
      <h3 class="title is-5">Cette certification est ?</h3>
      <div class="columns">
        <div class="column">
          <nuxt-link v-on:click.native="chooseType('A')" to="/recapitulatif" class="box">
            <input type="radio" name="answer"> &nbsp;Une première demande
          </nuxt-link>
          <nuxt-link v-on:click.native="chooseType('B')" to="/recapitulatif" class="box">
            <input type="radio" name="answer"> &nbsp;Un renouvellement
          </nuxt-link>
          <nuxt-link v-on:click.native="chooseType('C')" to="/recapitulatif" class="box">
            <input type="radio" name="answer"> &nbsp;Une prolongation
          </nuxt-link>
        </div>
      </div>
    </div>
    <div class="form-help">
      <h3 class="title is-4">Besoin d'aide ?</h3>
      <div class="form-help-content">
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      </div>
      <a href="#" class="button is-text">J'ai besoin de plus d'aide</a>
    </div>
  </div>
</template>

<script>
export default {
  layout: 'experience',
  mounted() {
    this.$store.commit('application/addRemplissage', 95)
    this.$store.commit('application/disableFormationStepper')
    this.$store.commit('application/changeTab', 2)
  },
  methods: {
    chooseType (e) {
      this.$store.commit('experiences/chooseType', e)
    },
  }
}
</script>

<style>

</style>
