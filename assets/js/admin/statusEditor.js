import React, { Component } from 'react';
import { render } from 'react-dom';
import {markdown} from 'markdown';
import moment from 'moment';
import DatePicker, { registerLocale, setDefaultLocale }  from 'react-datepicker';
import { fr } from 'date-fns/locale';

import 'react-datepicker/dist/react-datepicker.css';
import '../../css/admin/react-datepicker.scss';

registerLocale('fr', fr)
const DATE_FORMAT = 'DD/MM/YYYY à HH[h]mm';


class StatusForm extends React.Component {
  state = {
    isCancelable: this.props.status,
    isEdit: !this.props.status,
    status: this.props.status,
  }

  createStatus(e) {
    e.preventDefault();
    const $form = $(e.target);
    $.ajax($form.attr('action'), {
      method: 'POST',
      data: this.state.status,
      success: status => {
        this.setState({
          status,
          isEdit: false,
          isCancelable: true,
          feedback: {
            success: true,
            message: 'Le bandeau a bien été soumis.'
          }
        })
      },
      fail: () => {
        this.setState({
          isEdit: false,
          isCancelable: true,
          feedback: {
            success: false,
            message: 'Une erreur est survenue, ... sorry!'
          }
        })
      }
    });
  };

  editStatus(key, value) {
    const newState = {
      status: Object.assign({}, this.state.status, {
        [key]: ((key.indexOf("_at") > -1 && value) ? value.toISOString() : value)
      })
    }
    this.setState(newState)
  }

  deleteStatus(e) {
    $.ajax('/admin/status', {
      method: 'delete',
      success: status => {
        this.setState({
          status,
          isEdit: true,
          isCancelable: false,
          feedback: {
            success: true,
            message: 'Le bandeau a bien été supprimé.'
          }
        })
      }
    });
  }

  renderDateRange() {
    if (this.state.status) {
      if (this.state.status.starts_at && this.state.status.ends_at)
        return `du ${moment(this.state.status.starts_at).format(DATE_FORMAT)} au ${moment(this.state.status.ends_at).format(DATE_FORMAT)}`;
      if (this.state.status.starts_at)
        return `à partir du ${moment(this.state.status.starts_at).format(DATE_FORMAT)}`
      if (this.state.status.ends_at)
        return `jusqu'au ${moment(this.state.status.ends_at).format(DATE_FORMAT)}`
    }
  }

  render() {
    return (
      <div>
        {
          this.state.feedback && (
            <div className={`alert alert-${this.state.feedback.success ? 'success' : 'danger'}`}>
              {this.state.feedback.message}
            </div>
          )
        }
        <div className="col-sm-offset-2 col-sm-10" style={{marginBottom: '2rem'}}>
          <h1>Bandeau informatif</h1>
        </div>
        { !this.state.isEdit ? (
          <div>
            <p>Le message suivant sera affiché {this.renderDateRange()} : </p>
            <div className={`app-status alert alert-${this.state.status.level}`} dangerouslySetInnerHTML={{__html: markdown.toHTML(this.state.status.message)}}></div>
            <div className="row">
              <div className="col-sm-2">
                <button onClick={e => this.setState({isEdit: true})} className="btn btn-primary">Editer le message</button>
              </div>
              <div className="col-sm-2">
                <button onClick={e => this.deleteStatus(e)} className="btn btn-danger">Supprimer le message</button>
              </div>
            </div>
          </div>
        ) : (
          <form action="/admin/status" method="POST" className="form-horizontal" onSubmit={e => this.createStatus(e)}>
            <input type="hidden" name="_csrf_token" value={this.props.token} />
            <div className="form-group">
              <label htmlFor="status" className="col-sm-2 control-label">Niveau</label>
              <div className="col-sm-10">
                <select
                  className="form-control"
                  required
                  onChange={e => this.editStatus('level', e.target.value)}
                  value={this.state.status && this.state.status.level || ''}
                >
                  <option className="text-info" value="info">Info (gris)</option>
                  <option className="text-warning" value="warning">Warning (jaune)</option>
                  <option className="text-danger" value="danger">Danger (rouge)</option>
                  <option className="text-success" value="success">Success (vert)</option>
                  <option className="text-primary" value="primary">Primary (vert avril)</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="message" className="col-sm-2 control-label">
                Contenu
              <br />
              <small>(Possibilité d'utiliser le format <a href="https://guides.github.com/features/mastering-markdown/" target="_blank">markdown</a>)</small>
              </label>
              <div className="col-sm-10">
                <textarea
                  className="form-control"
                  rows="5"
                  required
                  onChange={e => this.editStatus('message', e.target.value)}
                  value={this.state.status && this.state.status.message || ''}
                />
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="starts_at" className="col-sm-2 control-label">Date de début</label>
              <div className="col-sm-10">
                <DatePicker
                  locale="fr"
                  timeCaption="Heure"
                  className="form-control"
                  showTimeSelect
                  dateFormat="dd/MM/yyyy HH:mm"
                  minDate={new Date()}
                  onChange={date => this.editStatus('starts_at', date)}
                  selected={this.state.status && this.state.status.starts_at && new Date(this.state.status.starts_at)}
                />
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="ends_at" className="col-sm-2 control-label">Date de fin</label>
              <div className="col-sm-10">
                <DatePicker
                  locale="fr"
                  timeCaption="Heure"
                  className="form-control"
                  showTimeSelect
                  dateFormat="dd/MM/yyyy HH:mm"
                  // minDate={this.state.status && this.state.status.starts_at && new Date(this.state.status.starts_at)}
                  minDate={new Date()}
                  onChange={date => this.editStatus('ends_at', date)}
                  selected={this.state.status && this.state.status.ends_at && new Date(this.state.status.ends_at)}
                />
              </div>
            </div>
            <div className="form-group">
              <div className="col-sm-offset-2 col-sm-2">
                <button type="submit" className="btn btn-primary">Enregistrer</button>
              </div>
              {this.state.isCancelable && (
                <div className="col-sm-2">
                  <button className="btn btn-info" onClick={e => this.setState({isEdit: false})}>Annuler</button>
                </div>
              )}
            </div>
          </form>
        )}
      </div>
    );
  }
}

document.addEventListener('DOMContentLoaded', e => {
  const $statusEditor = document.getElementById('status-editor');
  if ($statusEditor) {
    $.ajax('/admin/status')
      .then(status => {
        render( <StatusForm token={$statusEditor.dataset.token} status={status} />, $statusEditor)
      })
  }
})



