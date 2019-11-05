<template>
  <div class="avril__page">
    <div class="avril__page__form">
      <div class="avril__page__form--select">

        <h3 class="title is-2">Récapitulatif de votre dossier :</h3>

        <div class="field">
          <p>Est-ce exact ?</p>
          <div class="control">
            <nuxt-link to="/" class="is-ok button is-dark">
              Oui
            </nuxt-link>
          </div>
        </div>

      </div>
    </div>
    <div class="avril__page__help">
      Félicitations
    </div>
  </div>
</template>

<script>
// import Logo from '~/components/Logo.vue'
// const ioHook = require('iohook');
export default {
  mounted() {
    // this.$store.commit('application/addRemplissage', 100)
    console.log(this.$store.state.experiences)
  },
  methods: {
  }
}
</script>

<style>
.avril__page{
  width: 100%;
  text-align: center;
  padding-top: 20vh;
}
.avril__ajouter__experience {
  display: block
}
.is-equal-height {
   display: flex;
   flex-direction: column;
   height: 100%;
}
</style>
