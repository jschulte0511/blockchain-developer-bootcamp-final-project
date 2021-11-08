<form onSubmit={this.setSecret}>
    <input
        type="text"
        name="state-change"
        placeholder="Enter new secret..."
        value={this.state.storageValue}
        onChange={event => this.setState({ storageValue: event.target.value })} />
    <button type="submit"> Submit </button>
</form>