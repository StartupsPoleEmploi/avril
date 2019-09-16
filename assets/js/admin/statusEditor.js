import React, { Component } from 'react';
import { render } from 'react-dom';
import moment from 'moment';
import DatePicker, { registerLocale, setDefaultLocale }  from 'react-datepicker';
import { format } from 'date-fns';
// import parseISO from 'date-fns/parseISO'
import { fr } from 'date-fns/locale';

import 'react-datepicker/dist/react-datepicker.css';
import '../../css/admin/react-datepicker.scss';

registerLocale('fr', fr)
const DATE_FORMAT = 'DD/MM/YYYY HH:mm';

console.log(DATE_FORMAT)

class StatusForm extends React.Component {
  state = {
    isEdit: false,
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
          feedback: {
            success: true,
            message: 'Le bandeau a bien été soumis.'
          }
        })
      },
      fail: () => {
        this.setState({
          isEdit: false,
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
        [key]: value
      })
    }
    console.log(newState)
    this.setState(newState)
  }

  deleteStatus(e) {
    $.ajax('/admin/status', {
      method: 'delete',
      success: status => {
        this.setState({
          status,
          isEdit: true,
          feedback: {
            success: true,
            message: 'Le bandeau a bien été supprimé.'
          }
        })
      }
    });
  }

  renderDateRange() {
    console.log(format(this.state.status.starts_at, DATE_FORMAT, {locale: fr}))
    // if (this.state.status && this.state.status.starts_at) {
    //   if (this.state.status.ends_at) {
    //     return `de ${format(this.state.status.starts_at, DATE_FORMAT)} à ${format(this.state.status.ends_at, DATE_FORMAT)}`
    //   } else {
    //     return `de ${format(this.state.status.starts_at, DATE_FORMAT)}`
    //   }
    // }
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
        { this.props.status && !this.state.isEdit ? (
          <div>
            <p>Le message suivant sera affiché {this.renderDateRange()} : </p>
            <div className={`alert alert-${this.state.status.level}`}>{this.state.status.message}</div>
            <button onClick={e => this.setState({isEdit: true})} className="btn btn-primary">Editer le message</button>
            <button onClick={e => this.deleteStatus(e)} className="btn btn-danger">Supprimer le message</button>
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
                  <option className="text-info" value="info">Info</option>
                  <option className="text-warning" value="warning">Warning</option>
                  <option className="text-danger" value="danger">Danger</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label htmlFor="message" className="col-sm-2 control-label">Contenu</label>
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
                  selected={this.state.status && this.state.status.starts_at}
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
                  minDate={this.state.status && this.state.status.starts_at}
                  onChange={date => this.editStatus('ends_at', date)}
                  selected={this.state.status && this.state.status.ends_at}
                />
              </div>
            </div>
            <div className="form-group">
              <div className="col-sm-offset-2 col-sm-10">
                <button type="submit" className="btn btn-primary">Enregistrer</button>
              </div>
            </div>
          </form>
        )}
      </div>
    );
  }
}

class StatusFormWithBackend extends React.Component {
  if
}

document.addEventListener('DOMContentLoaded', e => {
  const $statusEditor = document.getElementById('status-editor');
  if ($statusEditor) {
    $.ajax('/admin/status')
      .then(status => {
        console.log(status)
        render( <StatusForm token={$statusEditor.dataset.token} status={status} />, $statusEditor)
      })
  }
})



