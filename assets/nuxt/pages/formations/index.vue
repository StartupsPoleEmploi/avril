<template>
  <div class="form">

    <div class="form-fields">

        <h3 class="title is-5">Quelle classe avez vous suivi en dernier ?</h3>

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
Sélectionnez la bonne case. Dites nous simplement quelle a été la dernière classe que vous avez fréquentée. Ne vous inquiétez pas, il s'agit d'une simple information, cela ne sert pas à évaluer votre candidature à la VAE.
Rappelez-vous, la seule condition pour demander votre diplôme en VAE est de justifier d'un an d'expérience.        </div>
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
