<template>
  <div class="avril__page">
    <div class="avril__page__form">
      <div class="avril__page__form--container">

        <div class="field">
          <label class="label">Name</label>
          <div class="control">
            <input class="input" type="text" placeholder="Text input">
          </div>
        </div>

        <div class="field">
          <div class="control">
            <nuxt-link to="accueil" class="button is-dark is-small is-pulled-right">
              Accueil
            </nuxt-link>
          </div>
        </div>

      </div>
    </div>
    <div class="avril__page__help">
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    </div>
  </div>
</template>

<script>
export default {
  layout: 'dev',
  components: {
    // Logo
  }
}
</script>

<style>

</style>
