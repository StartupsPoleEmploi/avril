<template>
  <div class="form">

    <div class="form-fields">

        <h3 class="title is-5">Quelle est votre dernière classe suivie ?</h3>

        <nuxt-link v-on:click.native="addClasse('A')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;Primaire, 6ème, 5ème, 4ème, 3ème, 1ère année de CAP ou BEP
        </nuxt-link>
        <nuxt-link v-on:click.native="addClasse('B')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;2ème, 1ère, 2ème année de CAP ou BEP
        </nuxt-link>
        <nuxt-link v-on:click.native="addClasse('C')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;Terminal
        </nuxt-link>
        <nuxt-link v-on:click.native="addClasse('D')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;1ère ou 2ème année de l'enseignement supérieur
        </nuxt-link>

        <nuxt-link v-on:click.native="addClasse('E')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;3ème année de l'enseignement supérieur
        </nuxt-link>
        <nuxt-link v-on:click.native="addClasse('F')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;4ème ou 5ème année de l'enseignement supérieur
        </nuxt-link>
        <nuxt-link v-on:click.native="addClasse('G')" to="formations/diplome" class="box">
          <input type="radio" name="answer"> &nbsp;6ème année de l'enseignement supérieur
        </nuxt-link>

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
// import Logo from '~/components/Logo.vue'
// const ioHook = require('iohook');
export default {
  layout: 'experience',
  mounted() {
    // this.$store.commit('application/addRemplissage', 40)
    this.$store.commit('application/enableFormationStepper')
    this.$store.commit('application/disableExperienceStepper')
    this.$store.commit('application/changeTab', 1)
  },
  methods: {
    addClasse (e) {
      this.$store.commit('experiences/addClasse', e)
    },
  }
}
</script>

<style>

</style>
