<template>
  <div class="form">

    <div class="form-fields">

        <h3 class="title">Avez-vous une attestation de comparabilité d'un diplôme délivré dans un pays étranger ?</h3>
        <div class="columns">
          <div class="column">
            <nuxt-link v-on:click.native="addComparatibilite('A')" to="rncp" class="box">
              <input type="radio" name="answer"> &nbsp;Oui
            </nuxt-link>
          </div>
          <div class="column">
            <nuxt-link v-on:click.native="addComparatibilite('B')" to="rncp" class="box">
              <input type="radio" name="answer"> &nbsp;Non
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
export default {
  layout: 'experience',
  mounted() {
    // this.$store.commit('application/addRemplissage', 60)
  },
  methods: {
    addComparatibilite (e) {
      this.$store.commit('experiences/addComparatibilite', e)
    },
  }
}
</script>

<style>

</style>
