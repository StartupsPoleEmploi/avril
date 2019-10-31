<template>
  <div class="form">

    <div class="form-fields">
        <h3 class="title is-5">Titre ou diplôme le plus élevé obtenu en France ?</h3>

            <nuxt-link v-on:click.native="addDiplome('A')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;Aucun diplôme
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('B')" to="autre" class="box">
                <input type="radio" name="answer"> &nbsp;Certificat d’étude primaire
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('C')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;Brevet des collèges (BEPC, DNB), Certificat de Formation Générale (niveau V bis)
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('D')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;CAP, BEP ou autre certification de niveau V (niveau CEC3 : 3)
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('E')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;Baccalauréat général, technologique, professionnel, ESEU, DAEU, ou autre certification de niveau IV (niveau CEC : 4)
            </nuxt-link>

            <nuxt-link v-on:click.native="addDiplome('F')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;DEUG, DUT, DEUST, BTS ou autre certification de niveau III (niveau. CEC : 5)
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('G')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;Licence, licence professionnelle, Maîtrise ou autre certification de niveau II (niveau CEC : 6)
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('H')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;DESS, Master, titre d’ingénieur ou autre certification de niveau I (niveau CEC : 7)
            </nuxt-link>
            <nuxt-link v-on:click.native="addDiplome('I')" to="autre" class="box">
              <input type="radio" name="answer"> &nbsp;Doctorat, DEA de niveau I (niveau CEC : 8)
            </nuxt-link>

            <div class="form-field-action field" style="margin-top: 20px">
              <div class="control">
                <nuxt-link v-on:click.native="addDiplome('H')" to="autre" class="is-ok button is-text is-pulled-left">
                  Remplir plus tard
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
// import Logo from '~/components/Logo.vue'
// const ioHook = require('iohook');
export default {
  layout: 'experience',
  mounted() {
    // this.$store.commit('application/addRemplissage', 50)
  },
  methods: {
    addDiplome (e) {
      this.$store.commit('experiences/addDiplome', e)
    },
  }
}
</script>

<style>

</style>
